import { Metadata } from 'next';
import { getList, getCategory } from '@/libs/microcms';
import { LIMIT } from '@/constants';
import Pagination from '@/components/Pagination';
import ArticleList from '@/components/ArticleList';

type Props = {
  params: Promise<{
    categoryId: string;
    name: string;
  }>;
};

export async function generateMetadata(props: Props): Promise<Metadata> {
  const params = await props.params;
  const { categoryId } = params;
  const category = await getCategory(categoryId);
  return {
    title: category.name,
    openGraph: {
      title: category.name,
    },
    alternates: {
      canonical: `/categories/${params.categoryId}`,
    },
  };
}

export default async function Page(props: Props) {
  const params = await props.params;
  const { categoryId } = params;
  const data = await getList({
    limit: LIMIT,
    filters: `categories[contains]${categoryId}`,
  });
  const category = await getCategory(categoryId);
  return (
    <>
      <ArticleList articles={data.contents} />
      <Pagination totalCount={data.totalCount} basePath={`/categories/${categoryId}`} />
    </>
  );
}